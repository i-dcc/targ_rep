module MolecularStructuresHelper
  def add_targ_vec_link(name)
    link_to_function name do |page|
      page.insert_html :bottom, :targeting_vectors, :partial => 'targ_vec', :object => TargetingVector.new
    end
  end
end
