module ActionController
  module Serialization
    include RenderJsonMeta
    include RenderJsonMeta::MetadataDefault
    include RenderJsonMeta::MetadataNaturalKey
    include RenderJsonMeta::MetadataWhereValues
    include RenderJsonMeta::MetadataNestedResources
    include RenderJsonMeta::MetadataReadOnly

  end
end
