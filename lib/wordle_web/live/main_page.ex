defmodule WordleWeb.MainPage do
  use WordleWeb, :live_view
  @max_retries 7

  def mount(_params, _session, socket) do
    word = Wordle.Game.get_word()
    word |> IO.inspect(label: "DEBUG: Answer generated")

    {:ok,
     assign(socket,
       answer: word,
       alphabet: ~c"qwertyuiopasdfghjklzxcvbnm" |> Enum.map(&<<&1>>),
       feedback: [
         [{:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}],
         [{:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}],
         [{:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}],
         [{:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}],
         [{:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}],
         [{:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}, {:blank, ""}]
       ],
       highlight: %{},
       correct_keys: %{},
       current: "",
       current_i: 0
     )}
  end

  ## On-screen keyboard key_clicked
  def handle_event("key_clicked", %{"key" => key}, socket)
      when byte_size(socket.assigns.current) < 5 do
    new_colour = if socket.assigns.highlight[key] == "", do: "", else: "bg-green-500"
    updated_key = socket.assigns.highlight |> Map.put(key, new_colour)

    Process.send_after(self(), {:reset_key, key}, 200)

    {:noreply,
     assign(socket,
       current: socket.assigns.current <> String.downcase(key),
       highlight: updated_key
     )}
  end

  def handle_event("key_clicked", %{"key" => _key}, socket) do
    {:noreply, assign(socket, current: socket.assigns.current)}
  end

  ## On-screen keyboard special_clicked
  def handle_event("special_clicked", %{"special" => special}, socket) when special == "enter" do
    handle_submit(socket, socket.assigns.current)
  end

  def handle_event("special_clicked", %{"special" => special}, socket)
      when special == "backspace" do
    {remaining, _last} = String.split_at(socket.assigns.current, -1)
    {:noreply, assign(socket, current: remaining)}
  end

  ## Keyboard submit_guess
  def handle_event("submit_guess", %{"guess" => guess}, socket) do
    handle_submit(socket, guess)
  end

  ## Keyboard update_guess
  def handle_event("update_guess", %{"guess" => guess}, socket) do
    last_character = String.last(guess)
    new_colour = if socket.assigns.highlight[last_character] == "", do: "", else: "bg-green-500"

    updated_key = socket.assigns.highlight |> Map.put(last_character, new_colour)

    Process.send_after(self(), {:reset_key, last_character}, 200)

    {:noreply,
     assign(socket,
       current: String.downcase(guess),
       highlight: updated_key
     )}
  end

  def handle_event("gain_focus", _params, socket) do
    {:noreply, socket}
  end

  def handle_info({:reset_key, key}, socket) do
    updated_key = Map.delete(socket.assigns.highlight, key)
    {:noreply, assign(socket, highlight: updated_key)}
  end

  defp color_class(:green), do: "text-green-500"
  defp color_class(:yellow), do: "text-yellow-500"
  defp color_class(:gray), do: "text-gray-400"
  defp color_class(_), do: ""

  defp handle_submit(socket, guess)
       when byte_size(guess) == 5 and length(socket.assigns.feedback) != @max_retries do
    answer = socket.assigns.answer
    current_i = socket.assigns.current_i
    word_valid? = Wordle.Game.check_word(guess)

    case word_valid? do
      true ->
        feedback = Wordle.Game.feedback(answer, guess)
        new_feedback = socket.assigns.feedback |> List.replace_at(current_i, feedback)

        correct_updated =
          Map.merge(
            socket.assigns.correct_keys,
            Enum.reduce(feedback, %{}, fn
              {:green, char}, acc -> Map.put(acc, char, "bg-green-500")
              {:yellow, char}, acc -> Map.put(acc, char, "bg-yellow-500")
              _unknown, acc -> acc
            end)
          )

        {:noreply,
         assign(socket,
           current: "",
           current_i: socket.assigns.current_i + 1,
           feedback: new_feedback,
           correct_keys: correct_updated
         )}

      _ ->
        {:noreply, assign(socket, current: "")}
    end
  end

  defp handle_submit(socket, _guess) do
    {:noreply, assign(socket, current: socket.assigns.current)}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-center p-5">Wordle with Elixir</h1>
    <.attempts feedback={@feedback} current={@current} current_i={@current_i} />
    <form phx-change="update_guess" phx-submit="submit_guess">
      <input
        type="text"
        name="guess"
        value={@current}
        maxlength="5"
        autofocus
        class="absolute inset-0 z-0 opacity-0 h-screen w-screen"
        phx-window-keydown="gain_focus"
        autocomplete="off"
      />
    </form>
    <div class="flex flex-col items-center w-full mt-5">
      <.keyboard alphabet={@alphabet} highlight={@highlight} correct_keys={@correct_keys} />
    </div>
    """
  end

  defp attempts(assigns) do
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

  defp keyboard(assigns) do
    rows = Enum.chunk_every(assigns.alphabet, 10)
    assigns = assign(assigns, :rows, rows)

    ~H"""
    <div class="flex flex-col gap-2 z-1">
      <div :for={row <- @rows} class="flex gap-2">
        <button
          :for={char <- row}
          phx-click="key_clicked"
          phx-value-key={char}
          class={"w-12 h-12 border-2 border-gray-300 flex items-center justify-center text-2xl font-bold uppercase rounded #{Map.get(assigns.correct_keys, char, false) || Map.get(assigns.highlight, char, "")}"}
        >
          {char}
        </button>
      </div>
      <div class="flex gap-2 justify-end">
        <button
          :for={special_btn <- ["enter", "backspace"]}
          phx-click="special_clicked"
          phx-value-special={special_btn}
          class="w-fit h-12 border-2 border-gray-300 flex items-center justify-center text-2xl font-bold uppercase rounded"
        >
          {special_btn}
        </button>
      </div>
    </div>
    """
  end
end
