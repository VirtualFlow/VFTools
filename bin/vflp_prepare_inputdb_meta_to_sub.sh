input_folder=$1
set -x

cd $input_folder
pwd_initial=${PWD}

for metatranch in $(ls -d */); do 
    cd $metatranch
    for tranch in $(ls *.tar); do 
        tar -xvf $tranch -C /dev/shm
        cd /dev/shm/${tranch/.tar}
        for collection in $(ls *.tar.gz); do 
            tar -xvzf $collection
            for smile_file in $(ls ${collection/.*}/*smi); do
                smile=$(cat $smile_file)
                smile_file_basename=$(basename $smile_file .smi)
                echo "$smile ${smile_file_basename}" >> ${collection/.tar.gz}.txt
            done
            rm -r ${collection/.*}
            mkdir -p ${pwd_initial}/${metatranch}/${tranch/.tar}
            cp ${collection/.tar.gz}.txt ${pwd_initial}/${metatranch}/${tranch/.tar}/
        done
        cd ..
        rm -r ${tranch/.tar}
        cd ${pwd_initial}/${metatranch}
    done
    cd ..
done
cd ${pwd_initial}/..
