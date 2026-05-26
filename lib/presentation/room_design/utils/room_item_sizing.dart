double defaultRoomItemWidth(String id) {
  switch (id) {
    case 'bed':
    case 'bed3':
      return 205;
    case 'sofa':
    case 'sofa2':
    case 'sofa3':
      return 220;
    case 'bath2':
    case 'shelf':
      return 170;
    case 'chair':
    case 'minichair':
    case 'heartchair':
      return 110;
    case 'lamp':
    case 'lamp2':
    case 'lamp3':
    case 'lamp4':
    case 'green_lamps':
      return 90;
    case 'plant':
    case 'plant2':
    case 'miniplant':
      return 90;
    case 'clock':
      return 70;
    case 'tableau':
    case 'curtain2':
      return 130;
    default:
      return 120;
  }
}
