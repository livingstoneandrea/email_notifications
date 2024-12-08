defmodule EmailNotifications.Services.EmailService do
  @moduledoc """
  Handles email sending logic and validation
  """
  alias EmailNotifications.Repositories.{ UserRepo, EmailRepo, ContactRepo, GroupRepo }
  require Logger

  @allowed_roles ["admin", "frontend"]

  def send_email(user_id, user_role, email_attrs) do
    with :ok <- validate_role(user_role),
         {:ok, user} <- UserRepo.get_user_by_id(user_id),
         {:ok, contact} <- ContactRepo.find_contact_by_email(email_attrs["to"]),
         email_data <- %{
          sender: user["_id"],
          recipient: contact["email"],
          subject: email_attrs["subject"],
          body: email_attrs["body"],
          status: "pending"
        },
         {:ok, saved_email} <- EmailRepo.create_email(email_data) do
      {:ok, saved_email}
    else
      {:error, :unauthorized} -> {:error, "Unauthorized"}
      {:error, :insufficient_permissions} -> {:error, "Insufficient permissions"}
      {:error, :user_not_found} -> {:error, "User not found"}
      {:error, :contact_not_found} -> {:error, "Contact not found"}
      {:error, reason} -> {:error, reason}
    end
  end


  def delete_email(email_id, user_id, user_role) do
    allowed_roles = ["admin", "frontend"]

    if user_role not in allowed_roles do
      {:error, :forbidden, "Insufficient permissions"}
    else
      case EmailRepo.get_email_by_id(email_id) do
        nil ->
          {:error, :not_found, "Email not found"}

        %{"sender" => sender} when sender != user_id ->
          {:error, :unauthorized, "Unauthorized to delete this email"}

        _ ->
          case EmailRepo.delete_by_id(email_id) do
            {:ok, _result} -> {:ok, "Email deleted successfully"}
            {:error, _reason} -> {:error, :server_error, "Failed to delete email"}
          end
      end
    end
  end

  def deliver_email(%{
    "recipient": recipient,
    "subject": subject,
    "body": body
    } = email) do
    # Simulate sending email
    payload = %{
      to: recipient,
      subject: subject,
      body: body,
      from: "noreply@example.com"
    }

    try do
      # Mock sending email (replace this with actual API integration)
      Logger.info("Sending email to #{recipient}: #{inspect(payload)}")
      {:ok, %{message: "Email sent successfully"}}
    rescue
      exception ->
        {:error, exception.message}
    end
  end

  def list_user_emails(user_id, user_role) do
    allowed_roles = ["admin", "frontend"]

    if user_role not in allowed_roles do
      {:error, :forbidden, "Insufficient permissions"}
    else
      case UserRepo.get_user_by_id(user_id) do
        {:error, _reason} ->
          {:error, :not_found, "User not found"}

        {:ok, user} ->
          emails = EmailRepo.find_by_sender(user["_id"])
          {:ok, emails}
      end
    end
  end


  def retry_email(user_id, user_role, email_id) do
    allowed_roles = ["frontend", "admin"]

    # Check if the user has the correct role
    if user_role not in allowed_roles do
      {:error, :forbidden, "Insufficient permissions"}
    else
      case UserRepo.get_user_by_id(user_id) do
        {:error, _} ->  # Adjusted for correct match on {:error, _}
          {:error, :not_found, "User not found"}

        {:ok, user} ->  # Extract user data correctly from the tuple
          if user["plan"] == "gold" do
            case EmailRepo.get_email_by_id(email_id) do
              {:error, _} -> {:error, :not_found, "Email not found"}
              {:ok, email} ->
                # Add logic for re-sending the email here
                EmailRepo.update_email_status(email_id, "retry")
                {:ok, "Email retried successfully"}
            end
          else
            {:error, :forbidden, "Only users with a gold plan can retry email"}
          end
      end
    end
  end

  def get_email_status(user_id, group_id) do
    case UserRepo.get_user_by_id(user_id) do
      {:error, _reason} ->
        {:error, :not_found, "User not found"}

      {:ok, user} ->
        # Check user plan
        if user["plan"] != "gold" do
          {:error, :forbidden, "Forbidden: Only users on Gold Plan can view email statuses"}
        else
          case GroupRepo.get_group_by_id(group_id) do
            {:error, _reason} ->
              {:error, :not_found, "Group not found"}

            {:ok, group} ->
              # Ensure user is the owner of the group
              if group["owner"] != BSON.ObjectId.decode!(user_id) do
                {:error, :unauthorized, "Unauthorized access"}
              else
                contact_ids = group["contacts"] # Get group contacts
                if Enum.any?(contact_ids, &is_nil/1) do
                  {:error, :bad_request, "Group contains invalid contact IDs"}
                else
                  # Get user emails
                  user_emails = UserRepo.get_users_emails_by_ids(contact_ids)

                  if Enum.empty?(user_emails) do
                    {:error, :not_found, "No users found in group contacts"}
                  else
                    email_list = Enum.map(user_emails, & &1.email)
                    # Get email statuses
                    emails = EmailRepo.get_emails_by_recipient(email_list)

                    status = %{
                      sent: Enum.count(Enum.filter(emails, fn e -> e.status == "sent" end)),
                      pending: Enum.count(Enum.filter(emails, fn e -> e.status == "pending" end)),
                      failed: Enum.map(
                        Enum.filter(emails, fn e -> e.status == "failed" end),
                        fn e -> e.recipient end
                      )
                    }

                    {:ok, status}
                  end
                end
              end
          end
        end
    end
  end

  def send_email_to_group(user_id, user_role, group_id, email_attrs) do
    with :ok <- validate_role(user_role),
         {:ok, user} <- UserRepo.get_user_by_id(user_id),
         {:ok, _group} <- GroupRepo.get_group_by_id(group_id),
         {:ok, contacts} <- ContactRepo.get_contacts_by_group(group_id) do
      # Create emails and collect their inserted ids
      email_results =
        Enum.reduce_while(contacts, {:ok, []}, fn contact, acc ->
          email_data = %{
            sender: user["_id"],
            recipient: contact["email"],
            subject: email_attrs["subject"],
            body: email_attrs["body"],
            status: "pending"
          }

          case EmailRepo.create_email(email_data) do
            {:ok, saved_email} ->
              # Add the inserted_id to the list
              {:cont, {:ok, [saved_email[:_id] | elem(acc, 1)]}} # Accumulate the inserted IDs
            {:error, reason} ->
              {:halt, {:error, reason}}  # Stop processing if any error occurs
          end
        end)

      case email_results do
        {:ok, inserted_ids} ->

          # dispatch_email_job(inserted_ids)
          {:ok, inserted_ids}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :unauthorized} -> {:error, "Unauthorized"}
      {:error, :insufficient_permissions} -> {:error, "Insufficient permissions"}
      {:error, :user_not_found} -> {:error, "User not found"}
      {:error, :group_not_found} -> {:error, "Group not found"}
      {:error, :contacts_not_found} -> {:error, "Contacts not found"}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_group_email_status(user_id, user_role, user_plan, group_id) do
    with :ok <- validate_role_and_plan(user_role, user_plan),
         {:ok, status} <- EmailRepo.get_group_email_status(group_id, user_id) do
      {:ok, status}
    else
      {:error, :unauthorized} -> {:error, "Unauthorized access"}
      {:error, :invalid_plan} -> {:error, "Only gold plan users can access this feature"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_role_and_plan("frontend", "gold"), do: :ok
  defp validate_role_and_plan(_, _), do: {:error, :invalid_plan}


  defp validate_role(role) when role in @allowed_roles, do: :ok
  defp validate_role(_), do: {:error, :insufficient_permissions}

end
