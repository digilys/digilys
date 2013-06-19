module ViewUtils
  def local(*args)
    variables = args.extract_options!
    variables.merge!(Hash[*args])
    variables.each { |variable, value| view.stub(variable).and_return(value) }
  end
end
