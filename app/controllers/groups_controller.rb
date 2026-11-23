class GroupsController < ApplicationController
  include DialogForms

  opens_in_dialog :new, :edit
  before_action :set_group, only: [:edit, :update, :destroy]

  def index
    @query = text_param(:q)
    @total = Group.count
    @groups = Group.matching(@query).includes(:characters).by_name
  end

  def new
    @group = Group.new
  end

  def edit; end

  def create
    @group = Group.new(group_params)
    return render(:new, status: :unprocessable_content) unless @group.save

    respond_saved "Group added successfully"
  end

  def update
    return render(:edit, status: :unprocessable_content) unless @group.update(group_params)

    respond_saved "Group updated successfully"
  end

  def destroy
    @group.destroy!
    respond_deleted "Group deleted"
  end

  private

  def set_group
    @group = Group.find(params.expect(:id))
  end

  def group_params
    fields = params.expect(group: [:name, :description])
    fields[:description] = fields[:description].strip.presence if fields[:description]
    fields
  end
end
