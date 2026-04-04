defmodule Wordle.Game do
  defp get_words do
    "/usr/share/dict/words"
    |> File.stream!()
    |> Stream.map(&String.trim/1)
  end

  def get_word(length \\ 5) do
    get_words()
    |> Stream.filter(&(String.length(&1) / 1 == length))
    |> Stream.map(&String.downcase/1)
    |> Enum.random()
  end

  def check_word(word, length \\ 5) do
    word in (get_words()
             |> Stream.filter(&(String.length(&1) / 1 == length))
             |> Stream.map(&String.downcase/1))
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

  def already_present?(feedback, guess) do
    reduced_feedback =
      Enum.map(feedback, fn word ->
        Enum.reduce(word, "", fn {_, char}, acc ->
          acc <> char
        end)
      end)

    guess in reduced_feedback
  end
end
