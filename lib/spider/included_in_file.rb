# Use plain text file to track cycles.

# A specialized class using a plain text to track items stored. It supports
# three operations: new, <<, and include? . Together these can be used to
# add items to the text file, then determine whether the item has been added.
#
# To use it with Spider use the check_already_seen_with method:
#
#  Spider.start_at('http://example.com/') do |s|
#    s.check_already_seen_with IncludedInFile.new('/tmp/crawled.log')
#  end
class IncludedInFile
    # Construct a new IncludedInFile instance.
    # @param filepath [String] as path of file to store crawled URL
    def initialize(filepath)
      @filepath = filepath
      File.write(@filepath, '') unless File.file?(@filepath)
    end
  
    # Add an item to the memcache.
    def <<(v)
      File.write(@filepath, "#{v}\r\n", File.size(@filepath), mode: 'a')
    end
  
    # True if the item is in the file.
    def include?(v)
      File.open(@filepath).each do |line|
        return true if v.to_s == line.chomp
      end
      return false
    end
  end
  