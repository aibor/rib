module RIB
  module MyModules
    class Yognaut
      TRIGGER = /\A(ACTION\s+salutes)\Z/ 
      
      def output( s, m, c )
        return nil, m[1] + "\nI am Dave ! Yognaut and I have the balls!"
      end
    end
  end
end
