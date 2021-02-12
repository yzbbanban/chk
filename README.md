
    function checkAttribute() internal returns(uint){
        //C：100，O：200，N：100，F：100，L：100，U：50，X：100
        //0~100,100~300,300~400,400~500,500~600,600~650,650~750
        uint256 random1 = uint256(keccak256(abi.encode(block.timestamp, 
                            msg.sender, randNonce))) % totalCount;
        if(random1>=0 && random1<100){
            return checkWordRest(1);
        }else if (random1>=100 && random1<300){
            return checkWordRest(2);
        }else if (random1>=300 && random1<400){
            return checkWordRest(3);
        }else if (random1>=400 && random1<500){
            return checkWordRest(4);
        }else if (random1>=500 && random1<600){
            return checkWordRest(5);
        }else if (random1>=600 && random1<650){
            return checkWordRest(6);
        }else if (random1>=650 && random1<750){
            return checkWordRest(7);
        }
    }

    function checkWordRest(uint256 _level) internal returns(uint256){
        if(_level==1){
            if(wordCRest>0){
                wordCRest = wordCRest.sub(1);
                return _level; 
            }
            _level=_level.add(1);
        }
        if(_level==2){
            if(wordORest>0){
                wordORest = wordORest.sub(1);
                return _level; 
            }
            _level=_level.add(1);
        }
        if(_level==3){
            if(wordNRest>0){
                wordNRest = wordNRest.sub(1);
                return 3; 
            }
            _level=_level.add(1);
        }
        if(_level==4){
            if(wordFRest>0){
                wordFRest = wordFRest.sub(1);
                return _level; 
            }
            _level=_level.add(1);
        }
        if(_level==5){
            if(wordLRest>0){
                wordLRest = wordLRest.sub(1);
                return _level; 
            }
            _level=_level.add(1);
        }
        if(_level==6){
            if(wordURest>0){
                wordURest = wordURest.sub(1);
                return _level; 
            }
            _level=_level.add(1);
        }
        if(_level==7){
            if(wordXRest>0){
                wordXRest = wordXRest.sub(1);
                return _level; 
            }
        }
    }