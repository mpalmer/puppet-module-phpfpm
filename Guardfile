guard :shell do
	watch(%r{^[^.].*/[^.][^/]*$}) { |m| puts "Running for #{m[0]}"; system("rake") }
end
