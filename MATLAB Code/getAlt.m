% [~,len] = size(pcObj);

useRings = 0;   %Use only some of the rings (set 1). Use all rings (set 0)

if(~exist('lidarData','var'))
    len1 = numMessages;
else
    [len1,~] = size(lidarData);
end
[len2,~] = size(odomData);

positionAll = zeros(len2,3,'double');
for i = 1:len2
    positionAll(i,:) = [odomData{i}.Pose.Pose.Position.X,...
        odomData{i}.Pose.Pose.Position.Y,...
        odomData{i}.Pose.Pose.Position.Z];
end

if(len2 > len1 + 1)
    odomIndex = 1 : ((len2 - 1)/len1): len2;
    odomIndex = floor(odomIndex);
    [~,len2] = size(odomIndex);
    odomData = odomData(odomIndex);
    len = min([len1,len2]);
elseif(len1 > len2)
    len = len2;
else
    len = len1;
end
len = 2;

pcGround = cell(1,len);
lidarDataTemp = cell(1,1);
timeLidar = zeros(len,1,'double');
timeOdom = zeros(len,1,'double');
seqLidar = zeros(len,1,'double');
seqOdom = zeros(len,1,'double');
for i = 1:len
    timeOdom(i) = odomData{i}.Header.Stamp.Sec +...
        (odomData{i}.Header.Stamp.Nsec * 1e-9);
    seqOdom(i) = odomData{i}.Header.Seq;
    
    i
%     locationNew = [0];
%     locationCount = 0;
%     for j = 1:pcCount
%         if(pcObj{i}.Location(j,3) <= 0)
%             locationCount = locationCount + 1;
%             locationNew(locationCount) = j;
%         end
%     end
%     [locationNew,~] = findNeighborsInRadius(pcObj{i},[0,0,0],2);
%     pcGround{i} = select(pcObj{i},locationNew);

    if(~exist('lidarData','var'))
        lidarDataTemp = readMessages(veloBag,i);
    else
        lidarDataTemp{1} = lidarData{i};
    end

    timeLidar(i) = lidarDataTemp{1}.Header.Stamp.Sec +...
        (lidarDataTemp{1}.Header.Stamp.Nsec * 1e-9);
    seqLidar(i) = lidarDataTemp{1}.Header.Seq;
%     Select only the first ring of Lidar Data
    ring0 = categorical(lidarDataTemp{1}.readField('ring'));
    ringIndices = find(ismember(ring0,{'0','1',}));
    
%     Get the location Data
    curPos = [odomData{i}.Pose.Pose.Position.X,...
        odomData{i}.Pose.Pose.Position.Y,...
        odomData{i}.Pose.Pose.Position.Z];
    
    locationData = readXYZ(lidarDataTemp{1});
    if(useRings == 1)
        locationData = locationData(ringIndices,:);
    end

    quat1 = [odomData{i}.Pose.Pose.Orientation.W,...
        odomData{i}.Pose.Pose.Orientation.X,...
        odomData{i}.Pose.Pose.Orientation.Y,...
        odomData{i}.Pose.Pose.Orientation.Z];
    
    rotm1 = quat2rotm(quat1);
    if i == 2
        rotm1  = rotm1 * -1;
    end
    locationData = locationData * rotm1;
%     curPos = curPos * rotm1;

    locationDataPos = locationData + curPos;
%     pcGround{i} = select(pcObj{i},ringIndices);

%     Build the Pointcloud MATLAB class object
    intensityData = readField(lidarDataTemp{1},'intensity');
    if(useRings == 1)
        intensityData = intensityData(ringIndices);
    end
    pcGround{i} = pointCloud(locationDataPos, 'Intensity', intensityData);
    
    if(i == 2)
%         pcOut = pcmerge(pcGround{1}, pcGround{2}, 0.00001);
        locationAll = [locationAll;locationDataPos];
    elseif(i == 1)
        locationAll = locationDataPos;
        initPos = curPos;
    elseif(i > 2)
%         pcOut = pcmerge(pcOut, pcGround{i}, 0.00001);
%         if(i == len)
            locationAll = [locationAll;locationDataPos];
%         end
    end
end
pcMergedAll = pointCloud(locationAll);
figure,pcshow(pcMergedAll);
hold on;
plot3(initPos(1),initPos(2),initPos(3),'go','MarkerSize',10,'MarkerFaceColor','g');
plot3(curPos(1),curPos(2),curPos(3),'ro','MarkerSize',10,'MarkerFaceColor','r');
hold off;
% figure,plot(timeOdom - timeLidar);
figure,plot(timeOdom);
% figure,plot(seqLidar);
hold on;
legend;
% plot(seqOdom);
plot(timeLidar);
hold off;