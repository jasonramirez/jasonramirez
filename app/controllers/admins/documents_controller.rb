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
    Dir.glob(Rails.root.join('app', 'views', 'admins', 'documents', '*.html.erb'))
       .map { |file| File.basename(file, '.html.erb') }
       .reject { |name| name == 'index' }
       .sort
  end
  
  def document_file_exists?(document_name)
    path = File.join(Rails.root.to_s, 'app', 'views', 'admins', 'documents', "#{document_name}.html.erb")
    File.exist?(path)
  end
end
