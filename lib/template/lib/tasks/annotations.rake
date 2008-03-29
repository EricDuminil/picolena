class SourceAnnotationExtractor
  def find(dirs=%w(app lib spec lang config))
    dirs.inject({}) { |h, dir| h.update(find_in(dir)) }
  end
end
