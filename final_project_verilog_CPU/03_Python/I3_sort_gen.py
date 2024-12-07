import numpy as np

def sort(v, n):
    for i in range(n):
        for j in range(i-1,-1,-1):
            if v[j] > v[j+1]:
                v[j], v[j+1] = v[j+1], v[j]
    return v



if __name__ == '__main__':
    # Modify your test pattern here
    n = 30
    v = [
  348, 174, 289, 112, 45, 392, 153, 237, 7, 66,
  411, 289, 71, 144, 389, 198, 311, 95, 34, 478,
  256, 108, 241, 322, 186, 55, 199, 364, 27, 305
    ]
    # print(v)

    with open('../00_TB/Pattern/I3/mem_D.dat', 'w') as f_data:
        f_data.write(f"{n:08x}\n")
        for ele in v:
            f_data.write(f"{ele:08x}\n")


    with open('../00_TB/Pattern/I3/golden.dat', 'w') as f_ans:
        f_ans.write('{:0>8x}\n'.format(n))
        for item in sort(v, n):
            f_ans.write('{:0>8x}\n'.format(item))