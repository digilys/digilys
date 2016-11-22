class TrashController < ApplicationController
  load_and_authorize_resource :suite
  before_filter :authorize_restore

  def index
    @suites = Suite.deleted.order("deleted_at desc").all
    @evaluations = Evaluation.deleted.
      joins("LEFT OUTER JOIN suites ON evaluations.suite_id = suites.id").
      where("evaluations.suite_id IS NULL OR suites.deleted_at IS NULL").
      order("suites.deleted_at desc").all
  end
end
