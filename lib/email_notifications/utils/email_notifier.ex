defmodule EmailNotifications.Utils.EmailNotifier do
  @moduledoc """
  Utility functions for sending emails with support for priority queuing
  """
  alias EmailNotifications.Services.EmailService
  alias EmailNotifications.Repositories.EmailRepo

  require Logger

  @default_priority :normal

  #send single email immediately
  def send_email_now(email_id) do
    case EmailRepo.get_email_by_id(email_id) do
      {:ok, email} ->
        normalize_email = normalize_keys(email)

        result = EmailService.deliver_email(normalize_email)
        update_email_status(email_id, result)
        result

      {:error, reason} ->
        {:error, "Email not found: #{inspect(reason)}"}
      end
    end

    # Queue emails for bulk sending with priority
  def queue_bulk_emails(email_ids, priority \\ @default_priority) when is_list(email_ids) do
    for email_id <- email_ids do
      case Exq.enqueue_in(
             Exq,
             to_string(priority),
             "email_delivery",
             0,
             [email_id]
           ) do
        {:ok, _job_id} ->
          Logger.info("Queued email #{email_id} for delivery with priority #{priority}")

        {:error, reason} ->
          Logger.error("Failed to queue email #{email_id}: #{inspect(reason)}")
      end
    end
  end

  # Helper function to update the status of an email in MongoDB
  defp update_email_status(email_id, {:ok, _response}) do
    EmailRepo.update_email_status(email_id, "sent")
    Logger.info("Email #{email_id} sent successfully.")
  end

  defp update_email_status(email_id, {:error, reason}) do
    EmailRepo.update_email_status(email_id, "failed", reason)
    Logger.error("Failed to send email #{email_id}: #{inspect(reason)}")
  end

  defp normalize_keys(map) when is_map(map) do
    map
    |> Enum.map(fn
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      {key, value} -> {key, value} # Leave atom keys as is
    end)
    |> Enum.into(%{})
  end


end
