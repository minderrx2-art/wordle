defmodule WordleWeb.Attempts do
  use Phoenix.Component

  defp color_class(:green), do: "text-green-500"
  defp color_class(:yellow), do: "text-yellow-500"
  defp color_class(:gray), do: "text-gray-400"
  defp color_class(_), do: ""

  attr :alphabet, :list, required: true

  def attempts(assigns) do
    ~H"""
    <div class="w-fit relative w-64 mx-auto z-1">
      <div>
        <%= for {row, index} <- Enum.with_index(@feedback) do %>
          <div class="flex gap-2 mb-1">
            <%= if index == @current_i do %>
              <%= for i <- 0..4 do %>
                <% char = String.at(@current, i) %>
                <div class="w-16 h-16 border-2 border-gray-300 flex items-center justify-center text-2xl font-bold uppercase rounded">
                  {char}
                </div>
              <% end %>
            <% else %>
              <%= for {state, char} <- row do %>
                <div class="w-16 h-16 border-2 border-gray-300 flex items-center justify-center text-2xl font-bold uppercase rounded">
                  <span class={"#{color_class(state)}"}>{char}</span>
                </div>
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
