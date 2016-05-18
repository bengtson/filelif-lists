defmodule Lists.GenWebPage do
  require EEx

  EEx.function_from_file(:def, :base, Path.expand("./templates/header.html.eex"))

  def page do

    Lists.GenWebPage.base

  end

end
