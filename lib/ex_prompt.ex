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

  @type prompt :: String.t()
  @type choices :: list(String.t())

  @doc """
  Reads a line from `:stdio` displaying the prompt that is passed in.

  In case of any errors or `:eof` this function will return the default value if present, or an empty string otherwise.

  ## Examples

  To ask a user for their name and await for the input:

    ExPrompt.string("What is your name?\n")

  To ask for a hostname defaulting to `localhost`:

    ExPrompt.string("What is the hostname?\n", "localhost")
  """
  @spec string(prompt) :: String.t()
  @spec string(prompt, String.t()) :: String.t()
  def string(prompt, default \\ "") do
    string_prompt(prompt, default)
    |> ask(default)
  end

  @doc "Alias for `string/2`."
  @spec get(prompt, String.t()) :: String.t()
  def get(prompt, default \\ ""), do: string(prompt, default)

  @doc """
  Same as `string/2` but it will continue to "prompt" the user in case of an empty response.
  """
  @spec string_required(prompt) :: String.t()
  def string_required(prompt) do
    case string(prompt) do
      "" -> string_required(prompt)
      str -> str
    end
  end

  @doc "Alias for `string_required/1`."
  @spec get_required(prompt) :: String.t()
  def get_required(prompt), do: string_required(prompt)

  @doc """
  Asks for confirmation to the user.
  It allows the user to answer or respond with the following options:
    - Yes, yes, YES, Y, y
    - No, no, NO, N, n

  In case that the answer is none of the above, it will prompt again until we do or the default value if it's present.

  ## Examples

  To ask whether the user wants to delete a file or not:

    ExPrompt.confirm("Are you sure you want to delete this file?")

  It's the same example above, returning false as default.

    ExPrompt.confirm("Are you sure you want to delete this file?", false)
  """
  @spec confirm(prompt) :: boolean()
  @spec confirm(prompt, boolean() | nil) :: boolean()
  def confirm(prompt, default \\ nil) do
    answer =
      prompt
      |> boolean_prompt(default)
      |> ask()
      |> String.downcase()

    cond do
      answer in ~w(yes y) -> true
      answer in ~w(no n) -> false
      answer == "" and default != nil -> default
      true -> confirm(prompt, default)
    end
  end

  @doc "Alias for `confirm/2`."
  @spec yes?(prompt) :: boolean()
  @spec yes?(prompt, boolean() | nil) :: boolean()
  def yes?(prompt, default \\ nil), do: confirm(prompt, default)

  @doc """
  Asks the user to select form a list of choices.
  It returns either the index of the element in the list
  or -1 if it's not found.

  This method tries first to get said element by the list number,
  if it fails it will attempt to get the index from the list of choices
  by the value that the user wrote.

  ## Examples
  
  To ask for a favorite color in a predefined list

    ExPrompt.choose("Favorite color?" , ~w(red green blue))
  
  It's the same example above, but defines to the second option (green) as default value if none is selected.

    ExPrompt.choose("Favorite color?" , ~w(red green blue), 2)
  """
  @spec choose(prompt, choices) :: integer()
  @spec choose(prompt, choices, integer()) :: integer()
  def choose(prompt, choices, default \\ -1) do
    IO.puts("")

    if default < -1 || default >= length(choices) do
      raise "Invalid default value, the value must be between -1 (none) and #{length(choices) - 1}"
    end

    answer =
      list_prompt(prompt, choices, default)
      |> ask()

    try do
      n = String.to_integer(answer)
      if n > 0 and n <= length(choices), do: n - 1, else: -1
    rescue
      _e in ArgumentError ->
        case answer do
          "" ->
            default
          _ ->
            case Enum.find_index(choices, &(&1 == answer)) do
              nil -> -1
              idx -> idx
            end
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
  @spec password(prompt) :: String.t()
  @spec password(prompt, hide :: boolean()) :: String.t()
  def password(prompt, hide \\ true) do
    prompt = String.trim(prompt)

    case hide do
      true ->
        pid = spawn_link(fn -> pw_loop(prompt) end)
        ref = make_ref()
        value = IO.gets(prompt <> " ")

        send(pid, {:done, self(), ref})
        receive do: ({:done, ^pid, ^ref} -> :ok)

        value

      false ->
        IO.gets(prompt <> " ")
    end
    |> String.trim()
  end

  defp pw_loop(prompt) do
    receive do
      {:done, parent, ref} ->
        send(parent, {:done, self(), ref})
        IO.write(:stderr, "\e[2K\r")
    after
      1 ->
        IO.write(:stderr, "\e[2K\r#{prompt} ")
        pw_loop(prompt)
    end
  end
  
  defp format_trailing(prompt, default \\ nil) do
    case Regex.named_captures(~r/(?<spaces>[[:space:]]*)$/, prompt) do
      %{"spaces" => ""} when default != nil ->
        "#{String.trim_trailing(prompt)} #{default} "
      %{"spaces" => ""} ->
        "#{String.trim_trailing(prompt)} "
      %{"spaces" => spaces} when default != nil ->
        "#{String.trim_trailing(prompt)} #{default}#{spaces}"
      %{"spaces" => spaces} ->
        "#{String.trim_trailing(prompt)}#{spaces}"
    end
  end
  
  defp format_choices(choices) do
    choices
    |> Enum.with_index()
    |> Enum.reduce("", fn {c, i}, acc ->
      "#{acc}  #{i + 1}) #{c}\n"
    end)
  end

  defp string_prompt(prompt, ""), do: format_trailing(prompt)
  defp string_prompt(prompt, nil), do: format_trailing(prompt)
  defp string_prompt(prompt, default), do: format_trailing(prompt, "(#{default})")

  defp boolean_prompt(prompt, nil), do: format_trailing(prompt, "[yn]")
  defp boolean_prompt(prompt, true), do: format_trailing(prompt, "[Yn]")
  defp boolean_prompt(prompt, false), do: format_trailing(prompt, "[yN]")
  
  defp list_prompt(prompt, choices, -1) do
    "#{format_choices(choices)}\n#{format_trailing(prompt)}"
  end
  
  defp list_prompt(prompt, choices, default) do
    "#{format_choices(choices)}\n" <> format_trailing(prompt, "(#{Enum.at(choices, default)})")
  end
  
  defp ask(prompt, default \\ nil) do
    case IO.gets(prompt) do
      :eof ->
        ""
      {:error, _reason} ->
        ""
      str ->
        case String.trim_trailing(str) do
          "" -> default || ""
          value -> value
        end
    end
  end

end
