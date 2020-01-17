module Providers
  class StatementOfCasesController < ProviderBaseController
    def show
      @form = StatementOfCases::StatementOfCaseForm.new(model: statement_of_case)
    end

    def update
      if upload_button_pressed?
        perform_upload
      elsif save_continue_or_draft(form)
        convert_new_files_to_pdf
      else
        render :show
      end
    end

    def destroy
      original_file = delete_original_and_pdf_files
      @successfully_deleted = files_deleted_message(original_file) unless original_file.nil?
      redirect_to providers_legal_aid_application_statement_of_case_path
    end

    private

    def perform_upload
      form.upload_button_pressed = true
      if form.save
        @successful_upload = successful_upload
        redirect_to providers_legal_aid_application_statement_of_case_path
      else
        @error_message = error_message
        render :show
      end
    end

    def error_message
      return unless form.errors.present?

      I18n.t('accessibility.problem_text') + ' ' + form.errors.messages[:original_file].first
    end

    def files_deleted_message(original_file)
      I18n.t('activemodel.attributes.statement_of_case.file_deleted', file_name: original_file.document.filename)
    end

    def successful_upload
      return if form.errors.present?

      I18n.t('activemodel.attributes.statement_of_case.file_uploaded', file_name: form.original_file.original_filename)
    end

    def convert_new_files_to_pdf
      statement_of_case.original_attachments.each do |attachment|
        PdfConverterWorker.perform_async(attachment.id)
      end
    end

    def upload_button_pressed?
      params[:upload_button].present?
    end

    def form
      @form ||= StatementOfCases::StatementOfCaseForm.new(statement_of_case_params)
    end

    def statement_of_case_params
      merge_with_model(statement_of_case, provider_uploader: current_provider) do
        params.require(:statement_of_case).permit(:statement, :original_file)
      end
    end

    def statement_of_case
      @statement_of_case ||= legal_aid_application.statement_of_case || legal_aid_application.build_statement_of_case
    end

    def delete_original_and_pdf_files
      original_attachment = Attachment.find(attachment_id)
      delete_attachment(Attachment.find(original_attachment.pdf_attachment_id)) if original_attachment.pdf_attachment_id.present?
      delete_attachment(original_attachment)
    rescue StandardError
      original_attachment
    end

    def delete_attachment(attachment)
      attachment.document.purge_later
      attachment.destroy
    end

    def attachment_id
      params[:attachment_id]
    end
  end
end
