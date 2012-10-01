
#Feature #9083

#id	username	                              email	                                  distribution_centre
#9	joel.schick	                            joel.schick@helmholtz-muenchen.de	      EUCOMM
#12	andreas.hoerlein@helmholtz-muenchen.de	andreas.hoerlein@helmholtz-muenchen.de	EUCOMM
#13	sonja.schick@helmholtz-muenchen.de	    sonja.schick@helmholtz-muenchen.de	    EUCOMM
#22	viola.maier@helmholtz-muenchen.de	      viola.maier@helmholtz-muenchen.de	      EUCOMM
#23	antje.buerger@helmholtz-muenchen.de	    antje.buerger@helmholtz-muenchen.de	    EUCOMM
#32	joachim.beig@helmholtz-muenchen.de	    joachim.beig@helmholtz-muenchen.de	    EUCOMM
#25	jdrapp@ucdavis.edu	                    jdrapp@ucdavis.edu	                    KOMP
#26	alejo.mujica@regeneron.com	            alejo.mujica@regeneron.com	            KOMP
#1	htgt	                                  htgt@sanger.ac.uk	                      WTSI
#2	mirKO	                                  hmp@sanger.ac.uk	                      WTSI
#3	regeneron	                              io1@sanger.ac.uk	                      WTSI
#6	er1	                                    this_acc_went_wrong@sanger.ac.uk	      WTSI
#7	db7	                                    db7@sanger.ac.uk	                      WTSI
#8	dg4	                                    dg4@sanger.ac.uk	                      WTSI
#10	do2	                                    do2@sanger.ac.uk	                      WTSI
#28	wr1@sanger.ac.uk	                      wr1@sanger.ac.uk	                      WTSI
#29	mh8@sanger.ac.uk	                      mh8@sanger.ac.uk	                      WTSI
#30	sp12	                                  sp12@sanger.ac.uk	                      WTSI
#37	aq2	                                    aq2@sanger.ac.uk	                      WTSI
#38	pm9@sanger.ac.uk	                      pm9@sanger.ac.uk	                      WTSI
#39	af11@sanger.ac.uk	                      af11@sanger.ac.uk	                      WTSI

targets =
[
  { :id => 9, :username => 'joel.schick', :centre =>'EUCOMM'},
  { :id => 12, :username => 'andreas.hoerlein@helmholtz-muenchen.de', :centre =>'EUCOMM'},
  { :id => 13, :username => 'sonja.schick@helmholtz-muenchen.de', :centre =>'EUCOMM'},
  { :id => 22, :username => 'viola.maier@helmholtz-muenchen.de', :centre =>'EUCOMM'},
  { :id => 23, :username => 'antje.buerger@helmholtz-muenchen.de', :centre =>'EUCOMM'},
  { :id => 32, :username => 'joachim.beig@helmholtz-muenchen.de', :centre =>'EUCOMM'},
  { :id => 25, :username => 'jdrapp@ucdavis.edu', :centre =>'KOMP'},
  { :id => 26, :username => 'alejo.mujica@regeneron.com', :centre =>'KOMP'},
  { :id => 1, :username => 'htgt', :centre =>'WTSI'},
  { :id => 2, :username => 'mirKO', :centre =>'WTSI'},
  { :id => 3, :username => 'regeneron', :centre =>'WTSI'},
  { :id => 6, :username => 'er1', :centre =>'WTSI'},
  { :id => 7, :username => 'db7', :centre =>'WTSI'},
  { :id => 8, :username => 'dg4', :centre =>'WTSI'},
  { :id => 10, :username => 'do2', :centre =>'WTSI'},
  { :id => 28, :username => 'wr1@sanger.ac.uk', :centre =>'WTSI'},
  { :id => 29, :username => 'mh8@sanger.ac.uk', :centre =>'WTSI'},
  { :id => 30, :username => 'sp12', :centre =>'WTSI'},
  { :id => 37, :username => 'aq2', :centre =>'WTSI'},
  { :id => 38, :username => 'pm9@sanger.ac.uk', :centre =>'WTSI'},
  { :id => 39, :username => 'af11@sanger.ac.uk', :centre =>'WTSI'}
]

User.transaction do
  targets.each do |target|
    user = User.find target[:id]

    raise "User has unexpected username - expected '#{target[:username]}' - found: '#{user.username}'" if target[:username] != user.username

    centre = Centre.find_by_name(target[:centre])
    raise "Cannot find centre '#{target[:centre]}'!" if ! centre

    user.centre = centre
    user.save!
  end
end
