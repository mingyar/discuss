defmodule Discuss.LayoutView do
  use Discuss.Web, :view

  require Discuss.TemplateCompiler
  Discuss.TemplateCompiler.compile_templates("web/templates/layout")
end
