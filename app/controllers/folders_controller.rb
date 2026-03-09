class FoldersController < ApplicationController
  def new
    @folder = Folder.new
  end

  def create
    @folder = Folder.new(folder_params)
  end

  def destroy
    @folder = Folder.find(params[:id])
    @folder.destroy
  end

  # TODO: add edit to folder controller

  private

  def folder_params
    params.expect(folder: :name)
  end
end
