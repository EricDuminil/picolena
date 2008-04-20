class IndexWriter < Ferret::Index::IndexWriter
  def initialize(params={})
    # TODO: Remove those debug lines!
    # puts "##################################################################Creating Writer!!!!!"
    
    # Add needed parameters
    params.merge!(:create_if_missing => true,
                  :path              => Picolena::IndexSavePath,
                  :analyzer          => Picolena::Analyzer
                  # huge performance impact?
                  # :auto_flush        => true
                  )
    # Creates the IndexWriter
    super(params)
    # Add required fields (content, filetype, probably_unique_id, ...)
    add_fields!
  end
  
  def self.remove
    Dir.glob(File.join(Picolena::IndexSavePath,'*')).each{|f| FileUtils.rm(f) if File.file?(f)}
  end
  
  private
  def add_fields!
    # No need to re-create any field.
    return unless field_infos.fields.empty?
    field_infos.add_field(:complete_path,      :store => :yes, :index => :yes)
    field_infos.add_field(:content,            :store => :yes, :index => :yes)
    field_infos.add_field(:basename,           :store => :no,  :index => :yes, :boost => 1.5)
    field_infos.add_field(:file,               :store => :no,  :index => :yes, :boost => 1.5)
    field_infos.add_field(:filetype,           :store => :no,  :index => :yes, :boost => 1.5)
    field_infos.add_field(:date,               :store => :yes, :index => :yes)
    field_infos.add_field(:probably_unique_id, :store => :no,  :index => :yes)
  end 
end