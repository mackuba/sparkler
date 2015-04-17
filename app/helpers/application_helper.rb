module ApplicationHelper
  def pluralize_errors(errors)
    errors.count == 1 ? 'this error' : 'these errors'
  end
end
