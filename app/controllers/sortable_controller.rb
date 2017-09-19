class SortableController < ApplicationController
  skip_authorization_check

  def reorder
    # Currently only reordering evaluations this way
    if params[:evaluation]
      i = 0
      params[:evaluation].each do |e_id|
        e = Evaluation.find(e_id)
        e.set_list_position(i)
        i = i + 1
      end
    end
    redirect_to :back
  end

end
