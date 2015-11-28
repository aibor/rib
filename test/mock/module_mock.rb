module ModuleMock
  module_function
  def [](name)
    [:Core, :Fact].include?(name) ? nil : false
  end
end
