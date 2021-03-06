require 'rails_helper'

RSpec.describe BankTransactionPresenter do
  subject(:presenter) { described_class.new(transaction, remarks) }

  let(:transaction) { create :bank_transaction, :uncategorised_credit_transaction }
  let(:remarks) { [] }

  it { is_expected.to be_a BankTransactionPresenter }

  describe '.headers' do
    subject(:headers) { described_class.headers }

    it { is_expected.to be_a Array }
    it { expect(headers.count).to eq 8 }
  end

  describe '.present!' do
    subject(:present!) { described_class.present!(transaction, remarks) }

    it { is_expected.to be_a Array }
  end

  describe '#present' do
    subject(:present) { presenter.present }

    it { is_expected.to be_a Array }
  end

  describe 'transformative methods' do
    describe 'happened_at' do
      subject(:happened_at) { presenter.build_transaction_hash[:happened_at] }

      it { is_expected.to eq transaction.happened_at.strftime('%d/%b/%Y') }
    end

    describe 'amounts' do
      context 'when the bank transaction is a credit' do
        describe 'amount_credit' do
          subject(:amount_credit) { presenter.build_transaction_hash[:amount_credit] }

          it { is_expected.to eq transaction.amount }
        end

        describe 'amount_debit' do
          subject(:amount_debit) { presenter.build_transaction_hash[:amount_debit] }

          it { is_expected.to be nil }
        end
      end

      context 'when the bank transaction is a debit' do
        let(:transaction) { create :bank_transaction, :uncategorised_debit_transaction }

        describe 'amount_credit' do
          subject(:amount_credit) { presenter.build_transaction_hash[:amount_credit] }

          it { is_expected.to be nil }
        end

        describe 'amount_debit' do
          subject(:amount_debit) { presenter.build_transaction_hash[:amount_debit] }

          it { is_expected.to eq transaction.amount }
        end
      end
    end

    describe 'category' do
      subject(:category) { presenter.build_transaction_hash[:category] }

      context 'when the meta_data is empty' do
        it { is_expected.to be nil }
      end

      context 'when the transaction has been categorized' do
        let(:transaction) { create :bank_transaction, :benefits }

        it 'displays the transaction_type name' do
          expect(category).to eq 'Child Benefit'
        end
      end
    end

    describe 'flagged' do
      subject(:flagged) { presenter.build_transaction_hash[:flagged] }
      context 'when no remarks are passed from the CFE result' do
        it { is_expected.to be nil }
      end

      context 'when a single remark is passed from the CFE result as a symbol' do
        let(:remarks) { [:unknown_frequency] }

        it { is_expected.to eq 'Unknown frequency' }
      end

      context 'when multiple remarks are passed from the CFE result as strings' do
        let(:remarks) { %w[amount_variation unknown_frequency] }

        it { is_expected.to eq 'Amount variation, Unknown frequency' }
      end
    end
  end
end
