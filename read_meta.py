import xml.etree.ElementTree as ET
from create_meta import create_meta, convert_location
from pathlib import Path
import argparse


def extract_from_filename(xml_node_filename):
    filename = xml_node_filename.text
    name_parts = filename.split('_')
    channel_name = name_parts[-2]
    tile_id = int(name_parts[-3].strip('m'))
    return channel_name, tile_id

def extract_position(xml_node_bounds):
    x = xml_node_bounds.get('StartX')
    y = xml_node_bounds.get('StartY')
    channel_id = xml_node_bounds.get('StartC')
    tile_id = xml_node_bounds.get('StartM')
    return int(channel_id), int(tile_id), int(x), int(y)


def get_tile_size(xml_image_node):
    size_x = xml_image_node.find('Bounds').get('SizeX')
    size_y = xml_image_node.find('Bounds').get('SizeY')
    tile_size = size_x + ' ' + size_y + ' 1'
    return tile_size


def main(args):
    xml = ET.parse(args.czi_xml)

    image_nodes = xml.findall('Image')

    arrangement = {}

    for image in image_nodes:
        channel_id, tile_id, x, y = extract_position(image.find('Bounds'))
        location = convert_location(x, y)
        if channel_id in arrangement:
            if tile_id not in arrangement[channel_id]:
                arrangement[channel_id][tile_id] = location
        else:
            arrangement[channel_id] = {tile_id: location}


    channel1 = arrangement[0]
    num_tiles = max(channel1.keys()) + 1
    tile_locations = list(channel1.values())

    tile_size = get_tile_size(image_nodes[0])
    bs_xml = create_meta(args.pattern_str, num_tiles, tile_size, tile_locations, args.data_dir)
    with open('%s/%s_for_bs.xml' %(args.out, Path(args.czi_xml).stem), 'w') as s:
        s.write(bs_xml)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("-czi_xml", type=str,
            required=True)
    parser.add_argument("-pattern_str", type=str,
            default="191114_hBrest_rep_b4-1-MIP_m{xxx}_DAPI_ORG.tif")
    parser.add_argument("-out", type=str,
            default="/nfs/team283_imaging/test_stitching/Tong")
    parser.add_argument("-data_dir", type=str,
            default="/data/")

    args = parser.parse_args()

    main(args)

