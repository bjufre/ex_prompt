defmodule ExPromptTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  test ".string/1 returns empty string when something fails" do
    assert capture_io("", fn ->
             ExPrompt.string("Favorite color?")
             send(self(), :eof)
           end) == "Favorite color? "

    assert_received :eof

    assert capture_io("", fn ->
             ExPrompt.string("Favorite color?")
             send(self(), {:error, :oops})
           end) == "Favorite color? "

    assert_received {:error, :oops}
  end

  test ".string/1 asks for an answer" do
    assert capture_io("blue", fn ->
             ExPrompt.string("Favorite color?")
             send(self(), "blue")
           end) == "Favorite color? "

    assert_received "blue"
  end
  
  test ".string/1 keeps the trailing spaces added by the user" do
    assert capture_io("blue\n", fn ->
             color = ExPrompt.string("Favorite color?\n\n  ")
             assert color == "blue"
           end) == "Favorite color?\n\n  "

  end
  
  test ".string/2 returns default value when empty is passed" do
    default = "red"
    assert capture_io("\n", fn ->
             response = ExPrompt.string("Favorite color?", default)
             assert response == default
           end) == "Favorite color? (#{default}) "
  end
  
  test ".string/2 keeps the trailing spaces added by the user and returns the default value when an empty value is passed" do
    default = "red"
    assert capture_io("\n", fn ->
             response = ExPrompt.string("Favorite color?\n\n  ", default)
             assert response == default
           end) == "Favorite color? (#{default})\n\n  "
  end

  test ".string_required/1 keeps asking until we get an answer" do
    assert capture_io("blue", fn ->
             ExPrompt.string("Favorite color?")
             send(self(), "")
             send(self(), "blue")
           end) == "Favorite color? "

    assert_received ""
    assert_received "blue"
  end

  test ".confirm/1 succeeds when the answer is either: 'yes, Yes, YES, y, Y' or 'no, No, NO, n, N'" do
    positive = ~w(y yes Yes YES)
    negative = ~w(n no No NO)

    for answer <- positive do
      assert capture_io(answer, fn ->
               response = ExPrompt.confirm("Are you sure?")
               send(self(), answer)
               assert response == true
             end) == "Are you sure? [yn] "

      assert_received ^answer
    end

    for answer <- negative do
      assert capture_io(answer, fn ->
               response = ExPrompt.confirm("Are you sure?")
               send(self(), answer)
               assert response == false
             end) == "Are you sure? [yn] "

      assert_received ^answer
    end
  end
  
  test ".confirm/1 keeps the trailing spaces added by the user" do
    assert capture_io("y\n", fn ->
      response = ExPrompt.confirm("Are you sure?\n\n  ")
      assert response == true
    end) == "Are you sure? [yn]\n\n  "
  end

  test ".confirm/1 keeps asking when the answer none of following: 'yes, Yes, YES, y, Y' or 'no, No, NO, n, N'" do
    assert capture_io("no", fn ->
             answer = ExPrompt.confirm("Are you sure?")
             send(self(), "nein")
             send(self(), "no")
             assert answer == false
           end) == "Are you sure? [yn] "

    assert_received "nein"
    assert_received "no"
  end

  test ".confirm/2 succeeds when default value is provided" do
    default_values = [{true, "[Yn]"}, {false, "[yN]"}]

    for {default, options} <- default_values do
      assert capture_io("\n", fn ->
               response = ExPrompt.confirm("Are you sure?", default)
               assert response == default
             end) == "Are you sure? #{options} "

    end
  end
  
  test ".confirm/2 keeps asking when default value is provided but a non empty value is passed'" do
    default_values = [{true, "[Yn]"}, {false, "[yN]"}]

    for {default, options} <- default_values do
      assert capture_io("non_boolean\nnon_empty\n\n", fn ->
               response = ExPrompt.confirm("Are you sure?", default)
               assert response == default
             end) == String.duplicate("Are you sure? #{options} ", 3)
    end
  end
  
  test ".confirm/2 keeps the trailing spaces added by the user and returns the default value when an empty value is passed" do
    assert capture_io("\n", fn ->
      response = ExPrompt.confirm("Are you sure?\n\n  ", true)
      assert response == true
    end) == "Are you sure? [Yn]\n\n  "
  end

  test ".choose/2 succeeds by list index" do
    assert capture_io("1", fn ->
             idx = ExPrompt.choose("Favorite color?", ~w(red green blue))
             send(self(), "1")
             assert idx == 0
           end) ==
             """

               1) red
               2) green
               3) blue

             Favorite color? 
             """
             |> String.trim_trailing("\n")

    assert_received "1"
  end
  
  test ".choose/2 keeps the trailing spaces added by the user and succeeds by list index" do
    assert capture_io("2\n", fn ->
             idx = ExPrompt.choose("Favorite color?\n\n  ", ~w(red green blue))
             assert idx == 1
           end) ==
             """

               1) red
               2) green
               3) blue

             Favorite color?\n\n  
             """
             |> String.trim_trailing("\n")
  end

  test ".choose/2 succeeds by list value" do
    assert capture_io("red", fn ->
             idx = ExPrompt.choose("Favorite color?", ~w(red green blue))
             send(self(), "red")
             assert idx == 0
           end) ==
             """

               1) red
               2) green
               3) blue

             Favorite color? 
             """
             |> String.trim_trailing("\n")

    assert_received "red"
  end

  test ".choose/2 returns -1 when list index out of boundaries" do
    assert capture_io("10", fn ->
             idx = ExPrompt.choose("Favorite color?", ~w(red green blue))
             send(self(), 10)
             assert idx == -1
           end) ==
             """

               1) red
               2) green
               3) blue

             Favorite color? 
             """
             |> String.trim_trailing("\n")

    assert_received 10
  end

  test ".choose/2 returns -1 when list value is not correct" do
    assert capture_io("none", fn ->
             idx = ExPrompt.choose("Favorite color?", ~w(red green blue))
             send(self(), "none")
             assert idx == -1
           end) ==
             """

               1) red
               2) green
               3) blue

             Favorite color? 
             """
             |> String.trim_trailing("\n")

    assert_received "none"
  end
  
  test ".choose/3 succeeds with default value" do
    assert capture_io("\n", fn ->
             idx = ExPrompt.choose("Favorite color?", ~w(red green blue), 1)
             assert idx == 1
           end) ==
             """

               1) red
               2) green
               3) blue

             Favorite color? (green) 
             """
             |> String.trim_trailing("\n")
  end
  
  test ".choose/3 keeps the trailing spaces added by the user succeeds with default value" do
    assert capture_io("\n", fn ->
             idx = ExPrompt.choose("Favorite color?\n\n  ", ~w(red green blue), 1)
             assert idx == 1
           end) ==
             """

               1) red
               2) green
               3) blue

             Favorite color? (green)\n\n  
             """
             |> String.trim_trailing("\n")
  end
  
  test ".choose/3 raise exception when default value is out ou bounds" do
    assert_raise RuntimeError, fn ->
      ExPrompt.choose("Favorite color?", ~w(red green blue), 4)
    end
  end

  test ".password/2 hides the password by default (when passing true)" do
    assert capture_io("test", fn ->
             pw = ExPrompt.password("Password:")
             send(self(), "test")
             assert pw === "test"
           end) == "Password: "

    assert_received "test"
  end

  test ".password/2 shows the password when passing `false`" do
    assert capture_io("test", fn ->
             pw = ExPrompt.password("Password:", false)
             send(self(), "test")
             assert pw == "test"
             IO.write("test")
           end) == "Password: test"

    assert_received "test"
  end
end
