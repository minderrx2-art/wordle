defmodule WordleWeb.Keyboard do
  use Phoenix.Component

  attr :alphabet, :list, required: true
  attr :highlight, :map, default: %{}
  attr :correct_keys, :list, default: []

  def keyboard(assigns) do
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
