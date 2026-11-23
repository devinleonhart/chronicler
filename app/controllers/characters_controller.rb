class CharactersController < ApplicationController
  include DialogForms

  opens_in_dialog :new, :edit
  before_action :set_character, only: [:edit, :update, :destroy]

  def index
    @query = text_param(:q)
    @total = Character.count
    @characters = Character.matching(@query).includes(:groups).by_name
  end

  def new
    @character = Character.new
  end

  def edit; end

  def create
    @character = Character.new(character_params)
    return render(:new, status: :unprocessable_content) unless @character.save

    respond_saved "Character added successfully"
  end

  def update
    return render(:edit, status: :unprocessable_content) unless @character.update(character_params)

    respond_saved "Character updated successfully"
  end

  def destroy
    @character.destroy!
    respond_deleted "Character deleted"
  end

  private

  def set_character
    @character = Character.find(params.expect(:id))
  end

  def character_params
    without_blank_ids(params.expect(character: [:name, :birth_date, :death_date, { group_ids: [] }]), :group_ids)
  end
end
