input_folder=$1
set -x
cd $input_folder

for metatranch in $(ls -d */); do 

    cd $metatranch
    for tranch in $(ls *.tar); do 
        tar -xvf $tranch
        cd ${tranch/.tar};
        for collection in $(ls *.tar.gz); do 
            tar -xvzf $collection
        done
        cd ..
    done
    cd ..
done
cd ..
