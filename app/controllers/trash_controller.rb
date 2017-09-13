class TrashController < ApplicationController
  load_and_authorize_resource :suite
  before_filter :authorize_restore

  def index
    @suites = deleted_suites
    @evaluations = deleted_evaluations
  end

  private

  def deleted_suites
    suites = []
    if current_user.has_role?(:admin) || current_user.has_role?(:planner) || current_user.is_instance_admin?
      suites = Suite.deleted.order("deleted_at desc").all.to_a
      unless current_instance.virtual?
        suites.select! {|s| s.instance && s.instance == current_instance}
      end
      if current_user.is_instance_admin?
        suites.select! {|s| s.instance && current_user.has_role?(:instance_admin, s.instance)}
      elsif current_user.has_role?(:planner)
        suites.select! {|s| s.instance && current_user.instances.index(s.instance)}
      end
    end 
    suites
  end

  def deleted_evaluations
    evaluations = []
    if current_user.has_role?(:admin) || current_user.has_role?(:planner) || current_user.is_instance_admin?
      evaluations = Evaluation.deleted.joins("LEFT OUTER JOIN suites ON evaluations.suite_id = suites.id").where("evaluations.suite_id IS NULL OR suites.deleted_at IS NULL").order("suites.deleted_at desc").all.to_a
      unless current_instance.virtual?
        evaluations.select! {|e| e.suite && e.suite.instance && e.suite.instance == current_instance}
      end
      if current_user.is_instance_admin?
        evaluations.select! {|e| e.suite && e.suite.instance && current_user.has_role?(:instance_admin, e.suite.instance)}
      elsif current_user.has_role?(:planner)
        evaluations.select! {|e| e.suite && e.suite.instance && current_user.instances.index(e.suite.instance)}
      end
    end
    evaluations
  end
end
