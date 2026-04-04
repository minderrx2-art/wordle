defmodule WordleWeb.Main do
  use WordleWeb, :live_view

  import WordleWeb.Attempts
  import WordleWeb.Keyboard

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
  def handle_event("key_clicked", %{"key" => key}, socket) do
    new_colour = "bg-green-500"
    updated_key = socket.assigns.highlight |> Map.put(key, new_colour)
    Process.send_after(self(), {:reset_key, key}, 200)

    cond do
      byte_size(socket.assigns.current) < 5 ->
        {:noreply,
         assign(socket,
           current: socket.assigns.current <> String.downcase(key),
           highlight: updated_key
         )}

      true ->
        {:noreply,
         assign(socket,
           current: socket.assigns.current,
           highlight: updated_key
         )}
    end
  end

  ## On-screen keyboard special_clicked
  def handle_event("special_clicked", %{"special" => special}, socket) do
    cond do
      special == "enter" ->
        handle_submit(socket, socket.assigns.current)

      special == "backspace" ->
        {remaining, _last} = String.split_at(socket.assigns.current, -1)
        {:noreply, assign(socket, current: remaining)}
    end
  end

  ## Keyboard submit_guess
  def handle_event("submit_guess", %{"guess" => guess}, socket) do
    handle_submit(socket, guess)
  end

  ## Keyboard update_guess
  def handle_event("update_guess", %{"guess" => guess}, socket) do
    last_character = String.last(guess)
    new_colour = "bg-green-500"

    updated_key = socket.assigns.highlight |> Map.put(last_character, new_colour)

    Process.send_after(self(), {:reset_key, last_character}, 200)

    cond do
      byte_size(socket.assigns.current) < 5 ->
        {:noreply,
         assign(socket,
           current: String.downcase(guess),
           highlight: updated_key
         )}

      byte_size(guess) < 5 ->
        {:noreply,
         assign(socket,
           current: String.downcase(guess),
           highlight: updated_key
         )}

      true ->
        {:noreply,
         assign(socket,
           current: socket.assigns.current,
           highlight: updated_key
         )}
    end
  end

  def handle_event("gain_focus", _params, socket) do
    {:noreply, socket}
  end

  defp handle_submit(socket, _guess) when length(socket.assigns.feedback) != @max_retries do
    answer = socket.assigns.answer
    current_i = socket.assigns.current_i
    current_word = socket.assigns.current

    already_present? = Wordle.Game.already_present?(socket.assigns.feedback, current_word)
    word_valid? = Wordle.Game.check_word(current_word)

    cond do
      already_present? ->
        {:noreply, assign(socket, current: "")}

      word_valid? ->
        feedback = Wordle.Game.feedback(answer, current_word)
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

      true ->
        {:noreply, assign(socket, current: "")}
    end
  end

  defp handle_submit(socket, _guess) do
    {:noreply, assign(socket, current: socket.assigns.current)}
  end

  def handle_info({:reset_key, key}, socket) do
    updated_key = Map.delete(socket.assigns.highlight, key)
    {:noreply, assign(socket, highlight: updated_key)}
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
end
