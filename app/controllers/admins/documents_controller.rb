class Admins::DocumentsController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'
  
  def index
    @documents = available_documents
  end
  
  def show
    @document = params[:document]
    
    # Check if the document template exists
    unless document_file_exists?(@document)
      redirect_to admins_documents_path, alert: "Document not found"
      return
    end
    
    # Render the specific document template with the documents layout
    render template: "admins/documents/#{@document}", layout: 'documents'
  end
  
  private
  
  def available_documents
    Dir.glob(documents_base_path.join('*.html.erb'))
       .map { |file| File.basename(file, '.html.erb') }
       .reject { |name| name == 'index' }
       .sort
  end
  
  def document_file_exists?(document_name)
    path = documents_base_path.join("#{document_name}.html.erb")
    File.exist?(path)
  end
  
  def documents_base_path
    Rails.root.join('app', 'views', 'admins', 'documents')
  end
end
