# coding: utf-8
module RIB
  module MyModules
    class Yognaut < RIB::MyModulesBase
      def trigger
        /\A(ACTION\s+salutes)\Z/ 
      end
      
      def output( s, m, c )
        return nil, m[1] + "\nI am Dave ! Yognaut and I have the balls!"
      end
    end
  end
end
