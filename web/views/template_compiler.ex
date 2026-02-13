defmodule Discuss.TemplateCompiler do
  @moduledoc """
  Helper module for compiling EEx templates at build time.
  
  This eliminates duplication across view modules by providing a macro
  that handles the repetitive template compilation logic.
  
  Usage in a view:
    defmodule Discuss.TopicView do
      use Discuss.Web, :view
      require Discuss.TemplateCompiler
      Discuss.TemplateCompiler.compile_templates("web/templates/topic")
    end
  """

  defmacro compile_templates(templates_path) do
    expanded_path = Path.expand(templates_path)
    templates = File.ls!(expanded_path)
    
    template_clauses = 
      for template_file <- templates,
          String.ends_with?(template_file, ".eex") do
        template_path = Path.join(expanded_path, template_file)
        template_name = String.replace_suffix(template_file, ".eex", "")
        code = Phoenix.Template.EExEngine.compile(template_path, nil)
        
        quote do
          @external_resource unquote(template_path)
          def render(unquote(template_name), var!(assigns)) do
            unquote(code)
          end
        end
      end
    
    # Add catch-all clause
    catch_all = quote do
      def render(template, _assigns) do
        raise "template #{inspect(template)} not found in #{__MODULE__}"
      end
    end
    
    [template_clauses, catch_all]
  end
end
