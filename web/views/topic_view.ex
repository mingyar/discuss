defmodule Discuss.TopicView do
  use Discuss.Web, :view

  require Discuss.TemplateCompiler
  Discuss.TemplateCompiler.compile_templates("web/templates/topic")
end
