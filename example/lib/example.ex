defmodule Example do
  def main(_argv) do
    IO.puts """
    Hello there!

    Let's try this!!!
    """

    name = ExPrompt.string_required("What's your name?\s")
    color = ExPrompt.choose("What's your favorite color?", ~w(Red Green Blue))
    sure = ExPrompt.confirm("Are you sure?")
    password = ExPrompt.password("Your super awesome password:")

    sure? = if sure, do: "were", else: "weren't"

    IO.puts """
    PERFECT!

    Your name is #{name} and favorite color is #{color}, to which you said that you #{sure?}.
    Finally your password is: #{password}
    """

    ExPrompt.confirm("Is this correct?")
  end
end