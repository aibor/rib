# coding: utf-8


RIB::Module.new :test_core do

  command :test do
    on_call { 'yo' }
  end

end
