defmodule Wordle.Game do
  def get_word(length \\ 5) do
    "/usr/share/dict/words"
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.filter(&(String.length(&1) / 1 == length))
    |> Stream.map(&String.downcase/1)
    |> Enum.random()
  end

  def feedback(answer, guess) do
    answer_list = String.graphemes(answer)
    guess_list = String.graphemes(guess)

    Enum.zip(answer_list, guess_list)
    |> Enum.map(fn
      {charAns, charGue} ->
        cond do
          charAns == charGue -> {:green, charGue}
          charGue in answer_list -> {:yellow, charGue}
          true -> {:gray, charGue}
        end
    end)
  end
end
