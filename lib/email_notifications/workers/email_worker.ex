defmodule EmailNotifications.Workers.EmailWorker do
  @moduledoc """
  Worker for processing queued emails delivery
  """
  alias EmailNotifications.Utils.EmailNotifier

  require Logger

  def perform(email_id) do
    Logger.info("Processing email #{email_id} from queue")
    EmailNotifier.send_email_now(email_id)
  end
end
