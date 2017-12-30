defmodule Example do
  @colors ~w(Red Green Blue)

  def main(_argv) do
    IO.puts """
    Hello there!

    Let's try this!!!
    """

    name = ExPrompt.string_required("What's your name?\s")
    color = ExPrompt.choose("What's your favorite color?", ~w(Red Green Blue))
    password = ExPrompt.password("Your super awesome password:")

    IO.puts """

    PERFECT!

    Your name is `#{name}` and favorite color is `#{Enum.at(@colors, color)}` and your password is: `#{password}`
    """

    sure? = ExPrompt.confirm("Is this correct?")

    if sure?, do: IO.puts("\nSee ya! :)"), else: IO.puts("\nOuch :(")
  end
end