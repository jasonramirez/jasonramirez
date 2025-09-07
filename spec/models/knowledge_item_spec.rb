require 'rails_helper'

RSpec.describe KnowledgeItem, type: :model do
  let(:knowledge_item) { create(:knowledge_item) }

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:category) }
    it { should validate_numericality_of(:confidence_score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(1).allow_nil }
  end

  describe 'scopes' do
    let!(:high_feedback_item) { create(:knowledge_item, feedback_score: 0.8, total_feedback_count: 10) }
    let!(:low_feedback_item) { create(:knowledge_item, feedback_score: 0.2, total_feedback_count: 8) }
    let!(:no_feedback_item) { create(:knowledge_item, feedback_score: 0.5, total_feedback_count: 0) }

    describe '.by_feedback_score' do
      it 'orders by feedback score descending' do
        expect(KnowledgeItem.by_feedback_score).to eq([high_feedback_item, no_feedback_item, low_feedback_item])
      end
    end

    describe '.well_rated' do
      it 'returns items with high feedback scores and sufficient feedback' do
        expect(KnowledgeItem.well_rated).to include(high_feedback_item)
        expect(KnowledgeItem.well_rated).not_to include(low_feedback_item, no_feedback_item)
      end
    end

    describe '.poorly_rated' do
      it 'returns items with low feedback scores and sufficient feedback' do
        expect(KnowledgeItem.poorly_rated).to include(low_feedback_item)
        expect(KnowledgeItem.poorly_rated).not_to include(high_feedback_item, no_feedback_item)
      end
    end
  end

  describe 'feedback scoring' do
    describe '#update_feedback_score' do
      context 'with positive feedback' do
        it 'increments positive and total feedback counts' do
          expect {
            knowledge_item.update_feedback_score(true, 1.0)
            knowledge_item.reload
          }.to change { knowledge_item.positive_feedback_count }.by(1.0)
           .and change { knowledge_item.total_feedback_count }.by(1.0)
        end

        it 'updates the feedback score' do
          knowledge_item.update_feedback_score(true, 1.0)
          knowledge_item.reload
          
          # With 1 positive out of 1 total, but blended with baseline (0.5)
          # confidence_multiplier = min(1/20, 1) = 0.05
          # blended_score = (1.0 * 0.05) + (0.5 * 0.95) = 0.525
          expect(knowledge_item.feedback_score).to eq(0.53) # rounded to 2 decimal places
        end

        it 'updates last_feedback_at timestamp' do
          expect {
            knowledge_item.update_feedback_score(true, 1.0)
            knowledge_item.reload
          }.to change { knowledge_item.last_feedback_at }
        end
      end

      context 'with negative feedback' do
        it 'increments only total feedback count' do
          expect {
            knowledge_item.update_feedback_score(false, 1.0)
            knowledge_item.reload
          }.to change { knowledge_item.total_feedback_count }.by(1.0)
           .and change { knowledge_item.positive_feedback_count }.by(0)
        end

        it 'updates the feedback score' do
          knowledge_item.update_feedback_score(false, 1.0)
          knowledge_item.reload
          
          # With 0 positive out of 1 total, but blended with baseline (0.5)
          # confidence_multiplier = min(1/20, 1) = 0.05
          # blended_score = (0.0 * 0.05) + (0.5 * 0.95) = 0.475
          expect(knowledge_item.feedback_score).to eq(0.48) # rounded to 2 decimal places
        end
      end

      context 'with weighted feedback' do
        it 'applies fractional weights correctly' do
          knowledge_item.update_feedback_score(true, 0.5)
          knowledge_item.reload
          
          expect(knowledge_item.total_feedback_count).to eq(0.5)
          expect(knowledge_item.positive_feedback_count).to eq(0.5)
        end
      end

      context 'with multiple feedback entries' do
        before do
          # Add several feedback entries to test confidence multiplier
          10.times { knowledge_item.update_feedback_score(true, 1.0) }
          5.times { knowledge_item.update_feedback_score(false, 1.0) }
        end

        it 'calculates correct feedback score with more data' do
          knowledge_item.reload
          
          # 10 positive out of 15 total = 0.667 raw score
          # confidence_multiplier = min(15/20, 1) = 0.75
          # blended_score = (0.667 * 0.75) + (0.5 * 0.25) = 0.625
          expect(knowledge_item.feedback_score).to eq(0.63) # rounded
        end
      end
    end

    describe '#feedback_satisfaction_rate' do
      it 'returns 0 when no feedback' do
        expect(knowledge_item.feedback_satisfaction_rate).to eq(0.0)
      end

      it 'calculates correct percentage' do
        knowledge_item.update_columns(
          positive_feedback_count: 8,
          total_feedback_count: 10
        )
        
        expect(knowledge_item.feedback_satisfaction_rate).to eq(80.0)
      end
    end

    describe '#has_sufficient_feedback?' do
      it 'returns false with default minimum' do
        knowledge_item.update_column(:total_feedback_count, 3)
        expect(knowledge_item.has_sufficient_feedback?).to be false
      end

      it 'returns true with sufficient feedback' do
        knowledge_item.update_column(:total_feedback_count, 10)
        expect(knowledge_item.has_sufficient_feedback?).to be true
      end

      it 'respects custom minimum count' do
        knowledge_item.update_column(:total_feedback_count, 8)
        expect(knowledge_item.has_sufficient_feedback?(10)).to be false
        expect(knowledge_item.has_sufficient_feedback?(5)).to be true
      end
    end

    describe '#feedback_quality_indicator' do
      it 'returns unknown for insufficient feedback' do
        knowledge_item.update_column(:total_feedback_count, 2)
        expect(knowledge_item.feedback_quality_indicator).to eq('unknown')
      end

      it 'returns excellent for high scores' do
        knowledge_item.update_columns(feedback_score: 0.85, total_feedback_count: 5)
        expect(knowledge_item.feedback_quality_indicator).to eq('excellent')
      end

      it 'returns good for good scores' do
        knowledge_item.update_columns(feedback_score: 0.65, total_feedback_count: 5)
        expect(knowledge_item.feedback_quality_indicator).to eq('good')
      end

      it 'returns average for medium scores' do
        knowledge_item.update_columns(feedback_score: 0.5, total_feedback_count: 5)
        expect(knowledge_item.feedback_quality_indicator).to eq('average')
      end

      it 'returns poor for low scores' do
        knowledge_item.update_columns(feedback_score: 0.3, total_feedback_count: 5)
        expect(knowledge_item.feedback_quality_indicator).to eq('poor')
      end

      it 'returns very_poor for very low scores' do
        knowledge_item.update_columns(feedback_score: 0.1, total_feedback_count: 5)
        expect(knowledge_item.feedback_quality_indicator).to eq('very_poor')
      end
    end
  end

  describe 'private methods' do
    describe '#recalculate_feedback_score' do
      it 'handles edge case of zero feedback' do
        knowledge_item.update_column(:total_feedback_count, 0)
        knowledge_item.send(:recalculate_feedback_score)
        # Should not change the score when there's no feedback
        expect(knowledge_item.feedback_score).to eq(0.5) # default value
      end

      it 'blends with baseline for low feedback counts' do
        knowledge_item.update_columns(
          positive_feedback_count: 1,
          total_feedback_count: 1
        )
        
        knowledge_item.send(:recalculate_feedback_score)
        
        # With very little feedback, should be heavily weighted towards baseline
        expect(knowledge_item.feedback_score).to be_between(0.5, 0.6)
      end

      it 'trusts raw score for high feedback counts' do
        knowledge_item.update_columns(
          positive_feedback_count: 20,
          total_feedback_count: 20
        )
        
        knowledge_item.send(:recalculate_feedback_score)
        
        # With lots of positive feedback, should be close to 1.0
        expect(knowledge_item.feedback_score).to be > 0.95
      end
    end
  end
end
