defmodule ExPrompt do
  @moduledoc """
  ExPrompt is a helper package to add interactivity to your
  command line applications as easy as possible.

  It allows common operations such as:
    - Asking for an answer.
    - Asking for a "required" answer.
    - Choosing between several options.
    - Asking for confirmation.
    - Asking for a password.
  """

  @type prompt :: String.t
  @type choices :: list(String.t)

  @doc """
  Reads a line from `:stdio` displaying the prompt that is passed in.

  In case of any errors or `:eof` this function will return and empty string.

  ## Examples

  To ask a user for their name and await for the input:

    ExPrompt.string("What is your name?\n")
  """
  @spec string(prompt) :: String.t
  def string(prompt) do
    case IO.gets(prompt) do
      :eof -> ""
      {:error, _reason} -> ""
      str -> String.trim_trailing(str)
    end
  end

  @doc """
  Same as `string/1` but it will continue to "prompt" the user in case of an empty response.
  """
  @spec string_required(prompt) :: String.t
  def string_required(prompt) do
    case string(prompt) do
      "" -> string_required(prompt)
      str -> str
    end
  end

  @doc """
  Asks for confirmation to the user.
  It allows the user to answer or respond with the following options:
    - Yes, yes, YES, Y, y
    - No, no, NO, N, n
  
  In case that the answer is none of the above, it will prompt again until we do.

  ## Examples

  To ask whether the user wants to delete a file or not:

    ExPrompt.confirm("Are you sure you want to delete this file?")
  """
  @spec confirm(prompt) :: boolean()
  def confirm(prompt) do
    answer =
      String.trim(prompt)
      |> Kernel.<>(" [Yn] ")
      |> string()
      |> String.downcase

    cond do
      answer in ~w(yes y) -> true
      answer in ~w(no n) -> false
      true -> confirm(prompt)
    end
  end

  @doc """
  Asks the user to select form a list of choices.
  It returns either the index of the element in the list
  or -1 if it's not found.

  This method tries first to get said element by the list number,
  if it fails it will attempt to get the index from the list of choices
  by the value that the user wrote.

  ## Examples

    ExPrompt.choose("Favorite color?" , ~w(red green blue))
  """
  @spec choose(prompt, choices) :: integer()
  def choose(prompt, choices) do
    IO.puts("")

    answer =
      Enum.with_index(choices)
      |> Enum.reduce("", fn {c, i}, acc ->
        "#{acc}\s\s#{i + 1}) #{c}\n"
      end)
      |> Kernel.<>("\n" <> String.trim(prompt) <> "\s")
      |> string()

    try do
      n = String.to_integer(answer)
      if n > 0 and n <= length(choices), do: n - 1, else: -1
    rescue
      _e in ArgumentError ->
        case Enum.find_index(choices, & &1 == answer) do
          nil -> -1
          idx -> idx
        end
    end
  end

  @doc """
  Asks for a password.

  This method will hide the password by default as the user types.
  If that's not the desired behavior, it accepts `false`, and the password
  will be shown as it's being typed.

  ## Examples

    ExPrompt.password("Password: ")

    ExPrompt.password("Password: ", false)
  """
  @spec password(prompt, hide :: boolean()) :: String.t
  def password(prompt, hide \\ true) do
    prompt = String.trim(prompt)

    case hide do
      true ->
        pid = spawn_link(fn -> pw_loop(prompt) end)
        ref = make_ref()
        value = IO.gets(prompt <> " ")

        send pid, {:done, self(), ref}
        receive do: ({:done, ^pid, ^ref} -> :ok)

        value
      false ->
        IO.gets(prompt <> " ")
    end
    |> String.trim
  end

  defp pw_loop(prompt) do
    receive do
      {:done, parent, ref} ->
        send parent, {:done, self(), ref}
        IO.write(:stderr, "\e[2K\r")
    after
      1 ->
        IO.write(:stderr, "\e[2K\r#{prompt} ")
        pw_loop(prompt)
    end
  end
end
