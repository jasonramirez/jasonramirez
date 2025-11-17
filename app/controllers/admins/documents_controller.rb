class Admins::DocumentsController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'
  
  def index
    @documents = Document.order(:title)
  end
  
  def show
    @document = find_document
    render layout: 'documents'
  end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)

    if @document.save
      redirect_to edit_admins_document_path(@document),
        notice: t("admins.flash.created")
    else
      redirect_to new_admins_document_path,
        alert: t("admins.flash.failed")
    end
  end

  def edit
    @document = find_document
  end

  def update
    @document = find_document

    if @document.update(document_params)
      redirect_to edit_admins_document_path(@document),
        notice: t("admins.flash.updated")
    else
      redirect_to edit_admins_document_path(@document),
        alert: t("admins.flash.failed")
    end
  end

  def destroy
    document = find_document

    if document.destroy
      redirect_to admins_documents_path,
        notice: t("admins.flash.destroyed")
    else
      redirect_to edit_admins_document_path(document),
        alert: t("admins.flash.failed")
    end
  end
  
  private
  
  def find_document
    Document.friendly.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:title, :content_markdown)
  end
end
