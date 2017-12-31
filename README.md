![ExPrompt](/assets/ExPrompt@2x.png)
[![Build Status](https://travis-ci.org/behind-design/ex_prompt.svg?branch=master)](https://travis-ci.org/behind-design/ex_prompt)
[![Hex pm](http://img.shields.io/hexpm/v/ex_prompt.svg?style=flat)](https://hex.pm/packages/ex_prompt)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_prompt.svg)](https://hex.pm/packages/ex_prompt)

ExPrompt is a helper package to add interactivity to your command line applications as easy as possible.

It allows common operations such as: _asking for an answer (required or not), choosing between several options, asking for confirmation and asking for a password_.

## Preview
![ExPrompt](/assets/ex_prompt.gif)

## Installation

The package can be installed by adding `ex_prompt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_prompt, "~> 0.1.3"}
  ]
end
```

## Documentation

See the full documentation and API at [hexdocs/ex_prompt](http://hexdocs.pm/ex_prompt).

#### `string(prompt)`
Prompts the user for some input.

```elixir
iex> ExPrompt.string("What is your name?")
iex> What is your name? |
```

#### `string_required(prompt)`
Same as `string` but if we get no response, it will keep asking until we do.

```elixir
iex> ExPrompt.string_required("What is your name?")
iex> What is your name? |
```

#### `choose(prompt, choices)`
Asks the user to choose between several options from a list.
It returns either the index of the element in the list
or -1 if it's not found.

This method tries first to get said element by the list number,
if it fails it will attempt to get the index from the list of choices
by the value that the user wrote.

```elixir
iex> ExPrompt.string_required("What is your favorite color?", ~w(Red Green Blue))
iex>
      1) Red
      2) Green
      3) Blue

  What is your favorite color? |
```

#### `confirm(prompt)`
Asks for confirmation to the user.
It allows the user to answer or respond with the following options:
  - Yes, yes, YES, Y, y
  - No, no, NO, N, n

In case that the answer is none of the above, it will prompt again until we do.

```elixir
iex> ExPrompt.confirm("Are you sure?")
iex> Are you sure? [Yn] |
```

#### `password(prompt, hide \\ true)`
Asks for a password.

This method will hide the password by default as the user types.
If that's not the desired behavior, it accepts `false`, and the password
will be shown as it's being typed.

```elixir
iex> ExPrompt.password("Your password:")
iex> Your password: |
```

# License

Check [LICENSE](https://github.com/behind-design/ex_prompt/blob/master/LICENSE).
