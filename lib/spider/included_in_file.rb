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
    # create file if not exists
    File.write(@filepath, '') unless File.file?(@filepath)
    @urls = File.readlines(@filepath).map(&:chomp)
  end

  # Add an item to the file & array of URL.
  def <<(v)
    @urls << v.to_s
    File.write(@filepath, "#{v}\r\n", File.size(@filepath), mode: 'a')
  end

  # True if the item is in the file.
  def include?(v)
    @urls.include? v.to_s
  end
end
