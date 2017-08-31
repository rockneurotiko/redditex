defmodule Handlers.Auth do
  defmacro __using__(_) do
    quote do
      def handle({:command, :start, %{text: data} = msg}, name, %{uid: uid}) do
        case String.split(data, "_") do
          [uids, code] ->
            case Integer.parse(uids) do
              {nuid, ""} ->
                if uid == nuid do
                  Reditex.user_auth_answer(%{"state" => uid, "code" => code})
                else
                  answer msg, "Nice try...", bot: name
                end
              _ ->
                answer msg, "Use /menu :)", bot: name
            end
          _ ->
            answer msg, "You need to authenticate: /auth", bot: name
        end
      end
    end
  end
end
