defmodule Handlers.Errors do
  defmacro __using__(_) do
    quote do
      def handle(_, name, %{update: msg, error: :create_user_info}) do
        Logger.info "ERROR"
        answer msg, "Some error happened, sorry!", bot: name
      end

      def handle({:command, :help, msg}, name, _) do
        answer msg, "Help? Not here:)", bot: name
      end

      def handle({:command, :auth, msg}, name, %{uid: uid}) do
        url = RedditApi.initial_authorize_url(uid)
        answer msg, "Authenticate here: #{url}", bot: name
      end

      def handle(_, name, %{update: msg, uid: uid, error: :auth}) do
        Logger.info "ERROR NO AUTH"
        url = RedditApi.initial_authorize_url(uid)
        answer msg, "You are not authenticated, follow the link: #{url}", bot: name
      end

      def handle(_, name, %{update: msg, error: :state}) do
        Logger.info "ERROR STATE"
        answer msg, "Some error happened, sorry!", bot: name
      end
    end
  end
end
